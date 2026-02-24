
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS WikiCount,
        MAX(u.CreationDate) AS AccountCreated
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopQuestions AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
    ORDER BY 
        p.Score DESC
    LIMIT 5
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)
    ORDER BY 
        ph.CreationDate DESC
    LIMIT 10
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.WikiCount,
    us.AccountCreated,
    tq.Title AS TopQuestionTitle,
    tq.Score AS TopQuestionScore,
    tq.OwnerDisplayName AS TopQuestionOwner,
    re.UserDisplayName AS EditorDisplayName,
    re.EditDate,
    re.Comment AS EditComment,
    re.Text AS EditedText
FROM 
    UserStats us
LEFT JOIN 
    TopQuestions tq ON us.QuestionCount > 0
LEFT JOIN 
    RecentEdits re ON us.UserId = CAST(re.UserDisplayName AS int)
WHERE 
    us.Reputation > 1000
ORDER BY 
    us.PostCount DESC, 
    us.Reputation DESC;
