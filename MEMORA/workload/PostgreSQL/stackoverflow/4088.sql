
WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(pc.CommentCount, 0) AS TotalComments,
        COALESCE(pa.AnswerCount, 0) AS TotalAnswers,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) pc ON p.Id = pc.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) pa ON p.Id = pa.ParentId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 3 WHEN b.Class = 2 THEN 2 ELSE 1 END) AS BadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.TotalComments,
        pa.TotalAnswers,
        ur.DisplayName,
        ur.BadgePoints,
        DENSE_RANK() OVER (ORDER BY pa.TotalAnswers DESC, pa.TotalComments DESC) AS PopularityRank
    FROM 
        PostActivity pa
    JOIN 
        UserReputation ur ON pa.OwnerUserId = ur.UserId
)
SELECT 
    ps.Title,
    ps.TotalComments,
    ps.TotalAnswers,
    ps.DisplayName,
    ps.BadgePoints,
    ps.PopularityRank
FROM 
    PostSummary ps
WHERE 
    ps.BadgePoints > 0
    AND (ps.TotalAnswers > 0 OR ps.TotalComments > 0)
ORDER BY 
    ps.PopularityRank
LIMIT 10;
