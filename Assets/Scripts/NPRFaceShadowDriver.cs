using UnityEngine;

// ===========================================================================
//  NPRFaceShadowDriver.cs
//  给 Hong/NPRToon 的"脸部 SDF"分支喂参数。
//
//  对应原 NPR 工程里的 SetNPRFacePosWS.cs，做了三点改进：
//    1. 只在数值真正变化时才写材质，避免 [ExecuteAlways] 每帧把材质标脏
//    2. 用 MaterialPropertyBlock 时不会脏化材质资源（可切换）
//    3. 自动开关 _FACEPOINT_ON 关键字，不用手动去材质面板勾
//
//  用法：
//    挂在角色脸部（或整个角色）的 SkinnedMeshRenderer 上 →
//    指定 Face Point（脸部中心的一个空物体）→ Head Bone（头骨）→
//    材质上勾选 Is Face，并打开 "整脸共享阴影坐标"。
// ===========================================================================

[ExecuteAlways]
[RequireComponent(typeof(SkinnedMeshRenderer))]
public class NPRFaceShadowDriver : MonoBehaviour
{
    [Tooltip("脸部 SDF 使用的材质；留空则自动取 Renderer 的第 0 个材质")]
    [SerializeField] private Material _material;

    [Tooltip("脸部中心点：整张脸共用这个点的阴影采样坐标")]
    [SerializeField] private Transform _facePoint;

    [Tooltip("头骨：用来推导脸的朝向轴")]
    [SerializeField] private Transform _headBone;

    [Header("自动推导朝向轴（按你的模型朝向调整）")]
    [SerializeField] private bool _autoSetFaceRight = true;
    [SerializeField] private bool _autoSetFaceForward = true;

    [Tooltip("_FaceRight 取 -headBone.forward（模型默认面朝 -Z 时正确）")]
    [SerializeField] private bool _negateHeadForwardForRight = true;

    [Tooltip("_FaceForward 取 headBone.up")]
    [SerializeField] private bool _useHeadUpForForward = true;

    [Header("写入方式")]
    [Tooltip("勾上则用 MaterialPropertyBlock（不脏化材质，但会打断这个物体的 SRP Batcher）")]
    [SerializeField] private bool _usePropertyBlock = false;

    [Tooltip("整脸共享阴影坐标：会自动开关材质上的 _FACEPOINT_ON 关键字")]
    [SerializeField] private bool _useSharedShadowPoint = true;

    private static readonly int FaceShadowPosWS = Shader.PropertyToID("_FaceShadowPosWS");
    private static readonly int FaceRightID     = Shader.PropertyToID("_FaceRight");
    private static readonly int FaceForwardID   = Shader.PropertyToID("_FaceForward");

    private Renderer _renderer;
    private MaterialPropertyBlock _block;
    private Vector4 _lastPos;
    private Vector4 _lastRight;
    private Vector4 _lastForward;

    private const string FacePointKeyword = "_FACEPOINT_ON";

    private void OnEnable()
    {
        CacheRenderer();
        Apply(force: true);
    }

    private void Update()
    {
        Apply(force: false);
    }

    private void CacheRenderer()
    {
        if (_renderer == null)
            _renderer = GetComponent<Renderer>();

        if (_material == null && _renderer != null)
            _material = _renderer.sharedMaterial;

        if (_block == null)
            _block = new MaterialPropertyBlock();
    }

    private void Apply(bool force)
    {
        CacheRenderer();
        if (_material == null || _facePoint == null)
            return;

        // ---- 位置 ----
        Vector3 pos = _facePoint.position;
        var pos4 = new Vector4(pos.x, pos.y, pos.z, 0f);

        // ---- 朝向轴 ----
        Vector4 right = new Vector4(0f, -1f, 0f, 0f);
        Vector4 forward = new Vector4(-1f, 0f, 0f, 0f);

        if (_headBone != null)
        {
            if (_autoSetFaceRight)
            {
                Vector3 dir = _negateHeadForwardForRight ? -_headBone.forward : _headBone.forward;
                right = new Vector4(dir.x, dir.y, dir.z, 0f);
            }

            if (_autoSetFaceForward)
            {
                Vector3 dir = _useHeadUpForForward ? _headBone.up : _headBone.forward;
                forward = new Vector4(dir.x, dir.y, dir.z, 0f);
            }
        }

        bool posChanged     = !Approximately(pos4, _lastPos);
        bool rightChanged   = !Approximately(right, _lastRight);
        bool forwardChanged = !Approximately(forward, _lastForward);

        if (!force && !posChanged && !rightChanged && !forwardChanged)
            return;

        if (_usePropertyBlock)
        {
            _renderer.GetPropertyBlock(_block);
            _block.SetVector(FaceShadowPosWS, pos4);
            if (rightChanged || force)   _block.SetVector(FaceRightID, right);
            if (forwardChanged || force) _block.SetVector(FaceForwardID, forward);
            _renderer.SetPropertyBlock(_block);
        }
        else
        {
            _material.SetVector(FaceShadowPosWS, pos4);
            if (rightChanged || force)   _material.SetVector(FaceRightID, right);
            if (forwardChanged || force) _material.SetVector(FaceForwardID, forward);
        }

        SetKeyword(_material, FacePointKeyword, _useSharedShadowPoint);

        _lastPos = pos4;
        _lastRight = right;
        _lastForward = forward;
    }

    private static void SetKeyword(Material mat, string keyword, bool on)
    {
        if (on) mat.EnableKeyword(keyword);
        else    mat.DisableKeyword(keyword);
    }

    private static bool Approximately(Vector4 a, Vector4 b)
    {
        return Mathf.Abs(a.x - b.x) < 1e-5f
            && Mathf.Abs(a.y - b.y) < 1e-5f
            && Mathf.Abs(a.z - b.z) < 1e-5f
            && Mathf.Abs(a.w - b.w) < 1e-5f;
    }
}
