
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(CHAR_LENGTH(p.Body), 0)) AS AvgPostLength,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        COUNT(DISTINCT ph.PostId) AS EditedPostCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.UserId
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalBounties,
    us.AvgPostLength,
    us.LastPostDate,
    phs.EditCount,
    phs.EditedPostCount
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryStats phs ON us.UserId = phs.UserId
ORDER BY 
    us.Reputation DESC;
