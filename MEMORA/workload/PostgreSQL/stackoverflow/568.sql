
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswersProvided,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersProvided,
        TotalViews,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS UserRank
    FROM 
        UserPostStats
)
SELECT 
    t.DisplayName,
    t.QuestionsAsked,
    t.AnswersProvided,
    t.TotalViews,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    rp.CreationDate
FROM 
    TopUsers t
LEFT JOIN 
    RankedPosts rp ON t.UserId = rp.PostId
WHERE 
    t.UserRank <= 10
ORDER BY 
    t.TotalViews DESC, rp.Score DESC;
