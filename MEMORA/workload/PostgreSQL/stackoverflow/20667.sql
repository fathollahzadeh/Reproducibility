WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        NTILE(4) OVER (ORDER BY u.Reputation DESC) AS ReputationQuartile
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.Views
),
PostHistoryDetails AS (
    SELECT 
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason,
        COUNT(DISTINCT p2.Id) AS RelatedPostLinks,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (14, 15) THEN 1 ELSE 0 END) AS LockUnlockCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Posts p2 ON pl.RelatedPostId = p2.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
UserFinalStats AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.QuestionCount,
        us.AnswerCount,
        us.Reputation,
        us.ReputationQuartile,
        COALESCE(p.LastEditDate, '1970-01-01') AS LastPostEdit,
        COALESCE(p.CloseReason, 'No Close Reason') AS LastCloseReason,
        COALESCE(p.RelatedPostLinks, 0) AS RelatedPostLinks,
        COALESCE(p.LockUnlockCount, 0) AS LockUnlockCount
    FROM 
        UserStats us
    LEFT JOIN 
        PostHistoryDetails p ON us.UserId = p.PostId  
)
SELECT 
    ufs.DisplayName,
    ufs.TotalPosts,
    ufs.QuestionCount,
    ufs.AnswerCount,
    ufs.Reputation,
    ufs.LastPostEdit,
    ufs.LastCloseReason,
    ufs.RelatedPostLinks,
    ufs.LockUnlockCount,
    CASE 
        WHEN ufs.ReputationQuartile IS NULL THEN 'No Data'
        ELSE CONCAT('Q', ufs.ReputationQuartile)
    END AS ReputationBand,
    CASE 
        WHEN ufs.AnswerCount / NULLIF(ufs.QuestionCount, 0) > 2 THEN 'High Answer Rate'
        WHEN ufs.AnswerCount IS NULL THEN 'No Answers'
        ELSE 'Normal Answer Rate'
    END AS AnswerRateDescription
FROM 
    UserFinalStats ufs
WHERE 
    ufs.Reputation > 1000
ORDER BY 
    ufs.Reputation DESC, 
    ufs.TotalPosts DESC
LIMIT 100;