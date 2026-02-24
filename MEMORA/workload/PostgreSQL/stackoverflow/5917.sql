
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ut.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        p.PostTypeId
    FROM 
        Posts p
    JOIN 
        Users ut ON p.OwnerUserId = ut.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerReputation,
        rp.PostTypeId
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 AND 
        rp.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT rp.PostId) AS QuestionsCreated,
        SUM(rp.Score) AS TotalScore,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RankedPosts rp ON p.Id = rp.PostId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.QuestionsCreated,
    us.TotalScore,
    us.TotalViews,
    us.AvgReputation,
    tq.Title AS TopQuestionTitle,
    tq.Score AS TopQuestionScore,
    tq.ViewCount AS TopQuestionViews
FROM 
    UserStats us
LEFT JOIN 
    TopQuestions tq ON us.UserId = tq.OwnerReputation
ORDER BY 
    us.QuestionsCreated DESC, 
    us.TotalScore DESC;
