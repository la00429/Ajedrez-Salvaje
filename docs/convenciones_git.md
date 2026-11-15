# Convenciones Git

## Ramas

- `main`: versión estable.
- `develop`: integración.
- `feature/<tema>`: funcionalidad.
- `docs/<tema>`: documentación.

No se deben borrar, fusionar ni reescribir ramas desde una tarea documental.

## Flujo

```bash
git clone <url>
cd Ajedrez-Salvaje
git switch develop
git pull --ff-only origin develop
git switch -c feature/nombre-corto
# editar y probar
git status
git add ruta/segura
git commit -m "feat: describe el cambio"
git push -u origin feature/nombre-corto
```

Para documentación use `docs/<tema>` y un mensaje `docs: ...`. Abra un Pull
Request hacia `develop`, describa alcance y pruebas, solicite revisión y
resuelva conflictos actualizando desde `develop` sin `reset`, `rebase` ni
commits de merge innecesarios. Tras aprobarse, la integración la realiza el
responsable del repositorio.