export interface RootDomain {
  domain: string
  cloudflareToken: string
}

export interface Repository {
  url: string
  folder: string
  domain: string
  type: 'backend' | 'frontend' | 'homepage' | 'gohcos'
  container: 'backend' | 'onedash' | 'homepage' | 'gohcos' | 'demo'
}

export interface FrontendDomain {
  domain: string
  container: 'onedash' | 'homepage' | 'demo'
  isWildcard: boolean
}

export interface DeploymentConfig {
  core: {
    secretKey: string
    debug: boolean
    siteUrl: string
    siteDomain: string
    appName: string
    systemPin: string
    systemPinLength: number
    disableDnsVerification: boolean
    frontendUrl: string
  }
  database: {
    name: string
    user: string
    password: string
    host: string
    port: number
  }
  keycloak: {
    serverUrl: string
    publicUrl: string
    realmName: string
    clientId: string
    clientSecret: string
    registrationClientId: string
    registrationClientSecret: string
    adminUsername: string
    adminPassword: string
    adminClientId: string
    frontendClientId: string
    jwtLeeway: number
    autoSyncPermissions: boolean
    enabled: boolean
    syncPermissions: boolean
    syncAsync: boolean
    ssoClientId: string
    ssoClientSecret: string
    ssoDiscoveryUri: string
    authFrontendClient: string
  }
  email: {
    backend: string
    host: string
    port: number
    useTls: boolean
    useSsl: boolean
    username: string
    password: string
    fromEmail: string
  }
  redis: {
    host: string
    port: number
  }
  celery: {
    brokerUrl: string
    resultBackend: string
    upstashUrl: string
  }
  stripe: {
    liveMode: boolean
    testPublicKey: string
    testSecretKey: string
    livePublicKey: string
    liveSecretKey: string
    connectTestClientId: string
    connectLiveClientId: string
    systemAccountId: string
    webhookSecret: string
    applicationFee: number
  }
  paypal: {
    mode: string
    testClientId: string
    testSecret: string
    liveClientId: string
    liveSecret: string
    webhookId: string
  }
  oscar: {
    shopName: string
    defaultCurrency: string
    systemCurrency: string
    taxRate: number
    trialDays: number
    authorizationAmount: number
    defaultRegistrar: string
    paidOrderStatus: string
    orderPaidLabel: string
  }
  security: {
    allowedDomains: string[]
    corsOrigins: string[]
    allowedHosts: string[]
    sessionCookieAge: number
  }
  logging: {
    logstashHost: string
    logstashPort: number
    logstashEnabled: boolean
  }
  helpdesk: {
    escalationEnabled: boolean
    escalationDays: number
    escalationMinutes: number
    onHoldEscalationMinutes: number
    autoCloseEnabled: boolean
    autoCloseDays: number
    includeStaffInitialFollowup: boolean
  }
  invoicing: {
    prefix: string
    numberStart: number
    defaultDueDays: number
    dueDays: number
    minimumHourlyBalance: number
  }
  business: {
    countryCode: string
    provinceState: string
    vatNumber: string
  }
  policies: {
    suspendForNonPayment: boolean
    daysBeforeSuspension: number
    usersCanEditAddress: boolean
    fraudDetectionEnabled: boolean
  }
  aws: {
    accessKeyId: string
    secretAccessKey: string
    region: string
  }
  cloudflare: {
    fullApiKey: string
    apiKey: string
    apiToken: string
    apiEmail: string
    accountId: string
    zoneId: string
    tunnelId: string
    tunnelSecret: string
    connectorId: string
    subdomainServiceUrl: string
    subdomainBase: string
  }
  nginx: {
    templatePath: string
    containerName: string
    sslCertPath: string
    sslKeyPath: string
  }
  ssl: {
    wildcardEnabled: boolean
    letsencryptEmail: string
    certbotConfDir: string
    wildcardDomainPath: string
  }
  system: {
    mainHostname: string
    alternateHostname: string
    mainIpAddress: string
    allDomains: string[]
    useSystemIpForTenantDns: boolean
    developmentIp: string
    productionIp: string
    productionHostname: string
  }
  chat: {
    showSeenStatus: boolean
    maxMessageLength: number
  }
  deployment: {
    serverIp: string
    githubUser: string
    githubToken: string
    letsencryptEmail: string
    cloudflareApiToken: string
    repositories: Repository[]
    rootDomains: RootDomain[]
    apiDomains: string[]
    frontendDomains: string[]
    keycloakDomains: string[]
    homepageDomains: string[]
    gohcosDomains: string[]
  }
}

export function createDefaultConfig(): DeploymentConfig {
  return {
    core: {
      secretKey: '',
      debug: false,
      siteUrl: '',
      siteDomain: '',
      appName: 'CLOUDTOOLS',
      systemPin: '',
      systemPinLength: 6,
      disableDnsVerification: false,
      frontendUrl: '',
    },
    database: {
      name: 'hcos_db',
      user: 'hcos_user',
      password: '',
      host: 'postgres',
      port: 5432,
    },
    keycloak: {
      serverUrl: '',
      publicUrl: '',
      realmName: 'master',
      clientId: 'hcos-backend',
      clientSecret: '',
      registrationClientId: 'hcos-backend',
      registrationClientSecret: '',
      adminUsername: 'admin',
      adminPassword: '',
      adminClientId: 'hcos-backend',
      frontendClientId: 'hcos-frontend',
      jwtLeeway: 5,
      autoSyncPermissions: true,
      enabled: true,
      syncPermissions: true,
      syncAsync: true,
      ssoClientId: '',
      ssoClientSecret: '',
      ssoDiscoveryUri: '',
      authFrontendClient: 'hcos-frontend',
    },
    email: {
      backend: 'django.core.mail.backends.smtp.EmailBackend',
      host: 'smtp.gmail.com',
      port: 587,
      useTls: true,
      useSsl: false,
      username: '',
      password: '',
      fromEmail: '',
    },
    redis: { host: 'redis', port: 6379 },
    celery: {
      brokerUrl: 'redis://redis:6379/0',
      resultBackend: 'django-db',
      upstashUrl: '',
    },
    stripe: {
      liveMode: false,
      testPublicKey: '',
      testSecretKey: '',
      livePublicKey: '',
      liveSecretKey: '',
      connectTestClientId: '',
      connectLiveClientId: '',
      systemAccountId: '',
      webhookSecret: '',
      applicationFee: 500,
    },
    paypal: {
      mode: 'sandbox',
      testClientId: '',
      testSecret: '',
      liveClientId: '',
      liveSecret: '',
      webhookId: '',
    },
    oscar: {
      shopName: '',
      defaultCurrency: 'USD',
      systemCurrency: 'USD',
      taxRate: 15.0,
      trialDays: 30,
      authorizationAmount: 1.0,
      defaultRegistrar: 'ENOM',
      paidOrderStatus: 'Processing',
      orderPaidLabel: 'Paid',
    },
    security: {
      allowedDomains: [],
      corsOrigins: [],
      allowedHosts: [],
      sessionCookieAge: 86400,
    },
    logging: { logstashHost: 'localhost', logstashPort: 5000, logstashEnabled: false },
    helpdesk: {
      escalationEnabled: true,
      escalationDays: 3,
      escalationMinutes: 60,
      onHoldEscalationMinutes: 120,
      autoCloseEnabled: true,
      autoCloseDays: 7,
      includeStaffInitialFollowup: false,
    },
    invoicing: {
      prefix: 'INV-',
      numberStart: 1004,
      defaultDueDays: 3,
      dueDays: 5,
      minimumHourlyBalance: 5.0,
    },
    business: { countryCode: 'US', provinceState: '', vatNumber: '' },
    policies: {
      suspendForNonPayment: true,
      daysBeforeSuspension: 7,
      usersCanEditAddress: true,
      fraudDetectionEnabled: false,
    },
    aws: { accessKeyId: '', secretAccessKey: '', region: 'us-east-1' },
    cloudflare: {
      fullApiKey: '',
      apiKey: '',
      apiToken: '',
      apiEmail: '',
      accountId: '',
      zoneId: '',
      tunnelId: '',
      tunnelSecret: '',
      connectorId: '',
      subdomainServiceUrl: '',
      subdomainBase: '',
    },
    nginx: {
      templatePath: '/etc/nginx/templates/nginx_template.conf',
      containerName: 'nginx_main',
      sslCertPath: '',
      sslKeyPath: '',
    },
    ssl: {
      wildcardEnabled: true,
      letsencryptEmail: '',
      certbotConfDir: '/etc/letsencrypt',
      wildcardDomainPath: '',
    },
    system: {
      mainHostname: '',
      alternateHostname: '',
      mainIpAddress: '',
      allDomains: [],
      useSystemIpForTenantDns: true,
      developmentIp: '',
      productionIp: '',
      productionHostname: '',
    },
    chat: { showSeenStatus: true, maxMessageLength: 2000 },
    deployment: {
      serverIp: '',
      githubUser: '',
      githubToken: '',
      letsencryptEmail: '',
      cloudflareApiToken: '',
      repositories: [
        {
          url: 'https://github.com/gohcosutilities/BACKEND-API-HCOM.git',
          folder: 'BACKEND-API-HCOM',
          domain: '',
          type: 'backend',
          container: 'backend',
        },
        {
          url: 'https://github.com/gohcosutilities/ONEDASH.HCOS.IO.git',
          folder: 'ONEDASH.HCOS.IO',
          domain: '',
          type: 'frontend',
          container: 'onedash',
        },
        {
          url: 'https://github.com/gohcosutilities/HOMEPAGE.git',
          folder: 'HOMEPAGE',
          domain: '',
          type: 'homepage',
          container: 'homepage',
        },
        {
          url: 'https://github.com/gohcosutilities/GOHCOSWEB.git',
          folder: 'GOHCOSWEB',
          domain: '',
          type: 'gohcos',
          container: 'gohcos',
        },
      ],
      rootDomains: [],
      apiDomains: [],
      frontendDomains: [],
      keycloakDomains: [],
      homepageDomains: [],
      gohcosDomains: [],
    },
  }
}

export const SECTIONS = [
  { key: 'deployment', label: 'Deployment', icon: '🚀' },
  { key: 'core', label: 'Core', icon: '⚙️' },
  { key: 'database', label: 'Database', icon: '🗄️' },
  { key: 'keycloak', label: 'Keycloak', icon: '🔐' },
  { key: 'email', label: 'Email', icon: '📧' },
  { key: 'redis', label: 'Redis', icon: '📡' },
  { key: 'celery', label: 'Celery', icon: '⏱️' },
  { key: 'stripe', label: 'Stripe', icon: '💳' },
  { key: 'paypal', label: 'PayPal', icon: '💰' },
  { key: 'oscar', label: 'E-Commerce', icon: '🛒' },
  { key: 'security', label: 'Security', icon: '🛡️' },
  { key: 'logging', label: 'Logging', icon: '📊' },
  { key: 'helpdesk', label: 'Helpdesk', icon: '🎫' },
  { key: 'invoicing', label: 'Invoicing', icon: '🧾' },
  { key: 'business', label: 'Business', icon: '🏢' },
  { key: 'policies', label: 'Policies', icon: '📋' },
  { key: 'aws', label: 'AWS', icon: '☁️' },
  { key: 'cloudflare', label: 'Cloudflare', icon: '🌐' },
  { key: 'ssl', label: 'SSL/Cert', icon: '🔒' },
  { key: 'nginx', label: 'Nginx', icon: '🌍' },
  { key: 'system', label: 'System', icon: '🖥️' },
  { key: 'chat', label: 'Chat', icon: '💬' },
] as const

export type SectionKey = (typeof SECTIONS)[number]['key']
