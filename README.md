# Vault

- [1 - Оптсание](#1-документация-по-развертыванию-запуску-и-функционалу)
- [2 - Развертывание и запуск проекта](#2-развертывание-и-запуск-проекта)
    - [2.1 - Клонирование репозитория](#21-клонирование-репозитория)
    - [2.2 - Переменные окружения](#22-настройте-переменные-окружения)
    - [2.3 - Настройка смарт контракта](#23-настройка-смарт-контракта)
    - [2.4 - Функционал обязательный к реализации](#24-при-создании-кастомной-стратегии-необходимо-реализовать-следующий-функционал)
    - [2.5 - Тесты](#25-скомпилируйте-и-протестируйте-ваши-контракт-смарт-контракты)
    - [2.6 - Деплой в сеть](#26-деплой-контрактов)
- [3 - Автоматизация](#3-инструкция-по-автоматизации-функций-смарт-контракта)
- [4 - Документация](https://github.com/LikeSouvenir/Vault/blob/main/docs/src/SUMMARY.md)
- [5 - Отчетная документация](https://github.com/LikeSouvenir/Vault/blob/main/Report.md)
## Вводная информация

Vault (хранилища) предоставляют пользователям возможность передавать свои активы в доверительное управление и получать от этого пассивный доход (yield). Этот подход значительно упрощает процесс формирования инвестиционного портфеля: пользователю не нужно глубоко изучать множество DeFi-протоколов или разбираться в сложных механизмах получения максимальной доходности. Разработчики автоматизировали все необходимые действия внутри стратегий vault'а, делая процесс инвестирования доступным даже новичкам.

[YouTube: Обзор основных моментов](https://www.youtube.com/watch?v=5okkzF4olZk)

[GitHub: Техническо задание](https://github.com/fullstack-development/solidity-developer-roadmap/blob/main/junior-1/practice/5-vault.md)


### **1. Документация по развертыванию, запуску и функционалу**

Этот документ содержит полное руководство по настройке среды и развертыванию проекта. 

Подробное описание ключевых функций смарт-контрактов находится в директории `/docs`.

#### **Предварительные требования**

Перед запуском убедитесь, что на вашей системе установлено:
*   **[Foundry](https://getfoundry.sh/)** - фреймворк для разработки смарт-контрактов
*   **[Node.js](https://nodejs.org/en)** (версия 18 или выше) и **Для работы с subgraph и Defender**

### **2. Развертывание и запуск проекта**

#### **2.1 Клонирование репозитория**
```bash
git clone https://github.com/LikeSouvenir/Vault.git
cd Vault
```

#### **2.2 Настройте переменные окружения:**
#### ! Убедитесь что у вас настроены файлы `.env` & `config.toml`. В противном случае измените файлы `/foundry/scripts/*`, `/foundry/config.toml` и `/foundry/foundry.toml`
*   Создайте файл `.env`
*   Заполните `.env` своими данными: приватными ключами для развертывания, API-ключами RPC-провайдеров (Infura, Alchemy) и т.д.

```dotenv
# Пример содержимого .env файла
RPC_URL_SEPOLIA=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
ETHERSCAN_API_KEY=YourEtherscanApiKey
#...
```

#### **2.3 Настройка смарт-контракта:**
* Основной контракт для управления - `/foundry/src/Vault.sol` - настроен и протестирован для работы. Является менеджером стратегий, наследует `BaseStrategy.sol`
* `/foundry/src/BaseStrategy.sol` - Базовый контракт, описывающий минимальный функционал для управления стратегией. Представляет абстракцию для инвестирования в существующие протоколы (Compound, Aave и др.).

Примеры стратегий в соответствующей директории - `./StrategyExamples/`
* `AaveUsdcStrategy.sol`
* `CompoundUsdcStrategy.sol`

#### **2.4 При создании кастомной стратегии необходимо реализовать следующий функционал:**

- Функция для вывода стредств

! Если входной и выходной токены различаются, функция должна выполнить обмен на базовый токен
```solidity
function _pull(uint256 amount) internal virtual returns (uint256);
```

- Функция пополнения средств

Необходимо учитывать особенности конечного контракта, будь то прямой перевод (transfer) или только разрешение на перевод (approve)
```solidity
function _push(uint256 amount) internal virtual;
```

- Функция отчетности

Учитывает весь баланс стратегии, т.е. токены на адресе конечного контракта и токены на самой стратегии

! В случае расхождения входного и выходного токена функция должна обменивать токен на базовый
```solidity
function _harvestAndReport() internal virtual returns (uint256 _totalAssets);
```

#### **2.5 Скомпилируйте и протестируйте ваши контракт смарт-контракты:**

```bash
forge build
forge test --no-matcm-path ./test/integrations/*
```

**`./test/integrations/*`** - исключаем из тестов fork тесты

### Анализ покрытия тестов

Общий вывод в консоль
```bash
forge coverage --match-contract "Test" --match-path "./test/unit/*" --report summary
```
**`--match-contract "Test"`** - выборка по названию тестов

**`--match-path "./test/unit/*"`** - выборка по пути

**`--report summary"`** - вывод сводной таблицы

**Детализированный отчет (HTML) с использовнием lcov & [genhtml](https://github.com/MrMichaelNealon/GenHTML)**

Для генерации HTML требуется установленный `genhtml`

Отчет будет находиться в директории ./coverage_report/

```bash
forge coverage --match-contract "Test" --match-path "./test/unit/*" --report lcov && genhtml -o coverage_report --branch-coverage lcov.info
```

**`--report lcov`** - отчет в формате lcov

**`genhtml -o`** - создание html в указанную для отчета директорию

**`--branch-coverage lcov.info`** - путь к lcov файлу

### Проверка безопасности
[slither](https://github.com/crytic/slither) - статический анализатор

Отчет по безопасности вашего контракта будет находиться в файле `./slitherResult.md`
```bash
slither . --include-path ./src/ --checklist > slitherResult.md
```
**`--checklist > slitherResult.md`** - выведет инофрмацию в файл

**`--include-path ./src/`** - указываем путь на наши файлы

#### **2.6 Деплой контрактов**

В директории **`/foundry/script/`** приведены примеры деплоя

После развертывания адреса контрактов будут выведены в консоль.
```bash
forge script --chain sepolia --broadcast --rpc-url <$YOUR_SEPOLIA_RPC_URL> <path/to/deploy_script:script_name> --verify --verifier etherscan --etherscan-api-key <$YOUR_ETHERSCAN_API_KEY> --private-key <$YOUR_DEV_PRIVATE_KEY> --optimize
```

**`--chain sepolia`** - сеть для разворота контракта

**`--broadcast`** - подтверждаем отправление в сеть

**`--rpc-url <$YOUR_SEPOLIA_RPC_URL>`** - ваш RPC провайдер

**`<path/to/deploy_script:script_name>`** - путь до скрипта:название

**`--verify --verifier etherscan`** - верификация через etherscan

**`--etherscan-api-key <$YOUR_ETHERSCAN_API_KEY>`** - ключ для etherscan

**`--private-key <$YOUR_DEV_PRIVATE_KEY>`** - с какого аккаунта отправить транзакцию (или `--interactives 1`)

**`--optimize`** - оптимизация

---
### 3. Инструкция по автоматизации функций смарт контракта

Для пример будет приведена автоматизация функции **`BaseStrategy.rebalanceAndReport()`** с использованием `OpenZeppelin Defender`

1. Регистрируемся на сайте https://defender.openzeppelin.com/
2. Создаем Relayer аккаунт
3. Выдаем ему роль для взаимодействия с функцией. `BaseStrategy.KEEPER_ROLE()`
4. Пополняем баланс Relayer аккаунта
5. Создаем Actions на соответствующей вкладки, указываем необходимые нам параметры
6. Вставляем код с директории `/autotask/CompoundUsdcStrategy.js` приведён пример кода для автоматизации
---
