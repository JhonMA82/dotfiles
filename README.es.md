# Sistema de Automatización de Configuración (cfg)

Gestión de dotfiles en lenguaje natural mediante chezmoi + skills de opencode. Diga "cambiar tema de ghostty a tokyo-night" y el sistema detecta el dominio, aplica el cambio, lo valida y lo versiona.

## Nueva máquina

En una instalación fresca de CachyOS:

1. Instalá opencode
2. Abrí este proyecto en opencode
3. Decí "bootstrap" o "inicializar dotfiles"
4. El skill `cfg-bootstrap` te guía paso a paso

Listo. Todos tus dotfiles, themes y configs aplicados.

## Ruta Rápida

1. Diga lo que desea: *"cambiar tema de ghostty a catppuccin-mocha"*
2. `cfg` detecta el dominio (ghostty) y la acción (tema)
3. El skill de dominio aplica, valida y versiona el cambio
4. Su configuración queda rastreada, se genera el diff y se hace commit.

## Skills Disponibles

| Skill | Rol | Visible al usuario |
|-------|------|-------------|
| `cfg` | Orquestador — análisis de intención, enrutamiento de dominio | Sí |
| `cfg-ghostty` | Terminal Ghostty — tema, fuente, atajos de teclado | Sí |
| `cfg-chezmoi` | Versionado compartido — add, re-add, diff, commit | No |

## El Pipeline

Cada skill de dominio sigue el mismo contrato de 5 pasos:

| Paso | Acción | ¿Bloquea al fallar? |
|------|--------|:---:|
| **READ** | Carga configuración desde chezmoi source + contexto de hardware desde `AGENTS.md` | No |
| **PLAN** | Determina campo, valor anterior→nuevo; verifica restricciones de hardware | No |
| **APPLY** | Edita chezmoi source, preserva estructura y comentarios | No |
| **VALIDATE** | Ejecuta validador del dominio (ej. `ghostty +validate-config`) | **Sí** |
| **VERSIONAR** | `chezmoi re-add` + commit convencional mediante `cfg-chezmoi` | No |

Formato de commit: `type(domain): description` — ej. `feat(ghostty): change theme to tokyo-night`.

## Agregar un Nuevo Dominio

```
.opencode/skills/cfg-{domain}/SKILL.md
```

Siga el contrato de `cfg-common.md`. Defina palabras clave de activación, el comando de validación (debe salir con 0), consideraciones de hardware desde `AGENTS.md` y la ruta de configuración en chezmoi source. Regenerar el registro con `/skill-registry`.

## Estrategia Multi-Máquina

`.chezmoi.yaml.tmpl` almacena la identidad por máquina (hostname, fuentes). Las plantillas usan bloques `{{ if eq .chezmoi.hostname "..." }}` para configuraciones específicas por máquina. Los skills de dominio leen los datos de la plantilla antes de aplicar. Configuración actual: MVP mono-máquina (`cachyos-x8664`).

## Valores Predeterminados Según Hardware

Cada skill lee `AGENTS.md` antes de sugerir configuraciones:

| Restricción | Impacto |
|------------|--------|
| Intel Broadwell-U GPU | Sin `background-blur`; usar `opacity` |
| 3.7 GiB RAM | Valores predeterminados ligeros; preferir skills |
| Niri Wayland | Establecer `linux_display_server wayland` |

## Estructura de Archivos

```
~/.local/share/chezmoi/          ← chezmoi source (versionado)
├── .chezmoi.yaml.tmpl           ← identidad de máquina
├── .chezmoiignore
└── dot_config/ghostty/config

.opencode/skills/                ← skills del proyecto (versionados)
├── _shared/
│   ├── cfg-common.md            ← contrato del pipeline
│   └── cfg-system.md            ← este documento
├── cfg/SKILL.md                 ← orquestador
├── cfg-chezmoi/SKILL.md         ← versionado
└── cfg-ghostty/SKILL.md         ← dominio ghostty
```

## Solución de Problemas

| Síntoma | Solución |
|---------|-----|
| "No cfg-{domain} skill found" | El skill no existe. Créelo o use un dominio conocido. |
| Falla la validación | Error de sintaxis en la configuración. Corrija y vuelva a aplicar. |
| chezmoi sobrescribe cambios | Editó el source, no el destino. Edite `~/.config/...` luego `chezmoi re-add`. |
| El commit no aparece | `chezmoi cd && git log --oneline -5` |

## Lista de Verificación

- [ ] Skills `cfg-*` registrados en `.atl/skill-registry.md`
- [ ] `.chezmoi.yaml.tmpl` tiene datos de máquina
- [ ] La validación aprueba antes de cada commit
- [ ] Los commits usan el formato `type(domain): description`
- [ ] `_shared/cfg-common.md` es la única fuente de verdad para el contrato del pipeline
