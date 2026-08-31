# PlayLivre — pacote para build Android

## Build pelo Codemagic
1. Envie esta pasta para um repositório GitHub.
2. Conecte o repositório ao Codemagic.
3. Use o workflow `android-debug`.
4. Inicie o build.
5. Baixe o arquivo `app-debug.apk` nos artefatos.

## Observação
O workflow gera a pasta Android automaticamente, caso ela ainda não exista.
O APK é de teste. Para publicar, será necessário configurar assinatura/release e usar conteúdo de áudio autorizado/licenciado.
