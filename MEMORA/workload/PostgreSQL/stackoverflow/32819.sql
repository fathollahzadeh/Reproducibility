WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5 
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        PHT.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
),

AnswerStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AvgAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    t.UserId,
    t.QuestionCount,
    t.PositiveScoredQuestions,
    rp.Title AS TopQuestionTitle,
    rp.Score AS TopQuestionScore,
    rp.ViewCount AS TopQuestionViews,
    phd.Comment AS RecentHistoryComment,
    ans.AnswerCount,
    ans.AvgAnswerScore
FROM 
    TopUsers t
JOIN 
    Users u ON t.UserId = u.Id
LEFT JOIN 
    RankedPosts rp ON t.UserId = rp.OwnerUserId AND rp.UserRank = 1
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN 
    AnswerStatistics ans ON rp.PostId = ans.PostId
WHERE 
    u.Reputation > 1000 
ORDER BY 
    t.QuestionCount DESC, 
    t.PositiveScoredQuestions DESC;