
WITH PostCounts AS (
    SELECT 
        PostTypeId, 
        COUNT(*) AS TotalPosts 
    FROM 
        Posts 
    GROUP BY 
        PostTypeId
),
UserCounts AS (
    SELECT 
        COUNT(*) AS TotalUsers 
    FROM 
        Users
),
BadgeCounts AS (
    SELECT 
        COUNT(*) AS TotalBadges 
    FROM 
        Badges
),
VoteCounts AS (
    SELECT 
        VoteTypeId, 
        COUNT(*) AS TotalVotes 
    FROM 
        Votes 
    GROUP BY 
        VoteTypeId
),
CommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS TotalComments 
    FROM 
        Comments 
    GROUP BY 
        PostId
)
SELECT 
    pc.PostTypeId,
    pc.TotalPosts,
    uc.TotalUsers,
    bc.TotalBadges,
    COALESCE(v.TotalVotes, 0) AS TotalVotes,
    COALESCE(cc.TotalComments, 0) AS TotalComments
FROM 
    PostCounts pc
CROSS JOIN 
    UserCounts uc
CROSS JOIN 
    BadgeCounts bc
LEFT JOIN 
    VoteCounts v ON v.VoteTypeId IN (1, 2, 3, 4, 5)
LEFT JOIN 
    CommentCounts cc ON cc.PostId = pc.PostTypeId
ORDER BY 
    pc.PostTypeId;
