// Select version from URL
const selectVersion = document.getElementById('select-version');
const indexOfFirstSlash = window.location.pathname.indexOf('/', 1);
const indexOfSecondSlash = window.location.pathname.indexOf('/', indexOfFirstSlash + 1);
const firstSegment = window.location.pathname.substring(1, indexOfFirstSlash);
const secondSegment = window.location.pathname.substring(indexOfFirstSlash + 1, indexOfSecondSlash);
var useFirstSegment = firstSegment.toLowerCase() !== 'everginedocs'? true : false;

// Load versions
const versionsUrl = useFirstSegment ? '/versions.json' : '/EvergineDocs/versions.json';
fetch(versionsUrl)
  .then(response => response.json())
  .then(json => {
      json.versions.forEach(version => {
        let option = document.createElement('option');
        option.value = version;
        option.innerText = version;
        option.className = "option-version";
        selectVersion.appendChild(option);
      });
    
      selectVersion.value = useFirstSegment? firstSegment : secondSegment;
    });

// Subscribe to version change
selectVersion.onchange = function() {
    const hostVersion = window.location.host;
    const pathVersion = window.location.pathname;
    let targetVersion = selectVersion.value;
    const segment = useFirstSegment? targetVersion : 'EvergineDocs' + '/' + targetVersion;
    const indexOfFirstSlash = pathVersion.indexOf('/', 1);
    const indexOfSecondSlash = pathVersion.indexOf('/', indexOfFirstSlash + 1);
    const slashToSkip = useFirstSegment? indexOfFirstSlash : indexOfSecondSlash;

    // Generate page URL in other version
    var newAddress = '//' + hostVersion + '/' + segment + '/' +  pathVersion.substring(slashToSkip + 1);

    // Check if address exists
    function handleErrors(response) {
        if (!response.ok) {
            throw Error(response.statusText);
        }
        return response;
    }

    fetch(newAddress)
        .then(handleErrors)
        .then(response => window.location.href = newAddress )
        .catch(error => window.location.href = '//' + hostVersion + '/' + segment);
};
 // Global n8n chat widget bootstrap for all DocFX pages.
  (function initN8nChatWidget() {
    const webhookUrl = 'https://wa-n8n-fec6hxfqb4cpgedb.westeurope-01.azurewebsites.net/webhook/9f9cd817-b58e-4001-8982-2cb55fa8a96b/chat';
    const chatCssId = 'n8n-chat-cdn-style';

    if (!webhookUrl || window.__n8nChatWidgetBootstrapping || window.__n8nChatWidgetInitialized) {
      return;
    }

    window.__n8nChatWidgetBootstrapping = true;

    if (!document.getElementById(chatCssId)) {
      const styleLink = document.createElement('link');
      styleLink.id = chatCssId;
      styleLink.rel = 'stylesheet';
      styleLink.href = 'https://cdn.jsdelivr.net/npm/@n8n/chat/dist/style.css';
      document.head.appendChild(styleLink);
    }

    if (!document.getElementById('n8n-chat-theme-overrides')) {
      const themeStyle = document.createElement('style');
      themeStyle.id = 'n8n-chat-theme-overrides';
      themeStyle.textContent = `
        :root,
        body.dark-theme {
          --chat--color--primary: #2ea3f2;
          --chat--color--primary-shade-50: #1d8fdd;
          --chat--header--background: var(--color-background-dark);
          --chat--toggle--background: var(--color-foreground);
          --chat--toggle--color: #337ab7;
          --chat--toggle--hover--background: var(--color-toc-hover);
        }

        body.light-theme {
          --chat--color--primary: #1469a8;
          --chat--color--primary-shade-50: #0f5a90;
          --chat--header--background: var(--color-background-dark);
          --chat--toggle--background: linear-gradient(135deg, #1469a8 0%, #0f5a90 100%);
          --chat--toggle--hover--background: #0b4a77;
        }
      `;
      document.head.appendChild(themeStyle);
    }

    import('https://cdn.jsdelivr.net/npm/@n8n/chat/dist/chat.bundle.es.js')
      .then((chatModule) => {
        if (window.__n8nChatWidgetInitialized) {
          return;
        }

        chatModule.createChat({
          webhookUrl: webhookUrl,
          mode: 'window',
          showWelcomeScreen: false,
          i18n: {
            en: {
              title: 'Evergine Assistant',
              subtitle: '',
              footer: '',
              getStarted: 'New conversation',
              inputPlaceholder: 'Type your question...',
              closeButtonTooltip: 'Close chat',
            },
          },
          initialMessages: [
            'Hi! I\'m GINA, the Evergine Assistant.',
            'I can help you find guides, APIs, and examples. What do you need?',
          ],
        });

        window.__n8nChatWidgetInitialized = true;
      })
      .catch((error) => {
        console.error('n8n chat widget failed to initialize:', error);
      })
      .finally(() => {
        window.__n8nChatWidgetBootstrapping = false;
      });
  })();
