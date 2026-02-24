WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.AnswerCount,
        us.QuestionCount,
        RANK() OVER (ORDER BY us.TotalPosts DESC) AS TotalPostsRank
    FROM 
        UserStatistics us
    WHERE 
        us.TotalPosts > 0
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    t.UserId,
    t.DisplayName AS TopUser,
    t.TotalPosts,
    t.AnswerCount,
    t.QuestionCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers t ON rp.Rank <= 5
WHERE 
    rp.Score > 10
  AND 
    rp.PostId NOT IN (SELECT DISTINCT ph.PostId 
                      FROM PostHistory ph 
                      WHERE ph.PostHistoryTypeId IN (10, 12)) 
ORDER BY 
    rp.Score DESC, 
    t.TotalPosts DESC
LIMIT 50;