
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveQuestions,
        SUM(p.ViewCount) AS TotalViews
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
ActivityHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        p.Title AS PostTitle
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)
)
SELECT 
    u.DisplayName,
    tu.QuestionsCount,
    tu.PositiveQuestions,
    tu.TotalViews,
    COUNT(DISTINCT ah.PostId) AS ActivityCount,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ah.CreationDate))) AS AvgTimeSinceLastActivity
FROM 
    TopUsers tu
JOIN 
    Users u ON tu.UserId = u.Id
LEFT JOIN 
    ActivityHistory ah ON u.Id = ah.UserId
GROUP BY 
    u.DisplayName, tu.QuestionsCount, tu.PositiveQuestions, tu.TotalViews
ORDER BY 
    AvgTimeSinceLastActivity ASC;
