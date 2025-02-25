/*
 *  Copyright (C) 2019 Team Kodi
 *  This file is part of Kodi - https://kodi.tv
 *
 *  SPDX-License-Identifier: GPL-2.0-or-later
 *  See LICENSES/README.md for more information.
 */

#pragma once

#include "ShaderGL.h"
#include "ShaderTextureGL.h"
#include "cores/RetroPlayer/shaders/IShaderPreset.h"
#include "cores/RetroPlayer/shaders/ShaderTypes.h"
#include "games/GameServices.h"
#include "utils/Geometry.h"

#include <memory>
#include <set>
#include <string>
#include <vector>

#include "system_gl.h"

namespace ADDON
{
class CShaderPreset;
class CShaderPresetAddon;
} // namespace ADDON

namespace KODI
{
namespace RETRO
{

class CRenderContext;

}

namespace SHADER
{

class IShaderTexture;
class CShaderPresetGL : public IShaderPreset
{
public:
  // Instance of CShaderPreset
  explicit CShaderPresetGL(RETRO::CRenderContext& context,
                           unsigned videoWidth = 0,
                           unsigned videoHeight = 0);

  ~CShaderPresetGL() override;

  // implementation of IShaderPreset
  bool ReadPresetFile(const std::string& presetPath) override;
  bool RenderUpdate(const CPoint dest[], IShaderTexture* source, IShaderTexture* target) override;
  void SetSpeed(double speed) override;
  void SetVideoSize(const unsigned videoWidth, const unsigned videoHeight) override;
  bool SetShaderPreset(const std::string& shaderPresetPath) override;
  const std::string& GetShaderPreset() const override;
  ShaderPassVec& GetPasses() override;
  bool Update();

private:
  bool CreateShaderTextures();
  bool CreateShaders();
  bool CreateBuffers();
  void UpdateViewPort();
  void UpdateViewPort(CRect viewPort);
  void UpdateMVPs();
  void DisposeShaders();
  void PrepareParameters(const IShaderTexture* texture, const CPoint dest[]);
  void RenderShader(IShader* shader, IShaderTexture* source, IShaderTexture* target) const;
  bool HasPathFailed(const std::string& path) const;

  // Construction parameters
  RETRO::CRenderContext& m_context;

  // Relative path of the currently loaded shader preset
  // If empty, it means that a preset is not currently loaded
  std::string m_presetPath;

  // Video shaders for the shader passes
  std::vector<std::unique_ptr<IShader>> m_pShaders;

  // Intermediate textures used for pixel shader passes
  std::vector<std::unique_ptr<CShaderTextureGL>> m_pShaderTextures;

  // First texture (this won't be needed when we have RGB rendering
  //std::unique_ptr<CShaderTextureCD3D> firstTexture;

  // Was the shader preset changed during the last frame?
  bool m_bPresetNeedsUpdate = true;

  // Size of the viewport
  float2 m_outputSize;

  // Size of the actual source video data (ie. 160x144 for the Game Boy)
  float2 m_videoSize;

  // Number of frames that have passed
  float m_frameCount = 0.0f;

  // Point/nearest neighbor sampler
  //ID3D11SamplerState* m_pSampNearest = nullptr;

  // Linear sampler
  //ID3D11SamplerState* m_pSampLinear = nullptr;

  // Set of paths of presets that are known to not load correctly
  // Should not contain "" (empty path) because this signifies that a preset is not loaded
  std::set<std::string> m_failedPaths;

  // Array of vertices that comprise the full viewport
  CPoint m_dest[4];

  // Playback speed
  double m_speed = 0.0;

  ShaderParameterMap GetShaderParameters(const std::vector<ShaderParameter>& parameters,
                                         const std::string& sourceStr) const;

  ShaderPassVec m_passes;
};

} // namespace SHADER
} // namespace KODI
