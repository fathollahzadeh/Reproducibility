
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(c.Score), 0) AS TotalCommentScore,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ups.DisplayName,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalCommentScore,
    ups.TotalBountyEarned,
    rp.Title,
    rp.ViewCount,
    rp.Score
FROM 
    UserPostStats ups
LEFT JOIN 
    RankedPosts rp ON ups.UserId = rp.PostId
WHERE 
    rp.Rank <= 3 OR rp.Rank IS NULL
ORDER BY 
    ups.TotalBountyEarned DESC, ups.TotalCommentScore DESC;
