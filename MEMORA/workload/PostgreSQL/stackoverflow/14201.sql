WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.ParentId) AS TotalAnswers,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostTypeCounts AS (
    SELECT 
        p.PostTypeId,
        COUNT(p.Id) AS Count
    FROM 
        Posts p
    GROUP BY 
        p.PostTypeId
),
VotesSummary AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalAnswers,
    ups.LastPostDate,
    ptc.PostTypeId,
    ptc.Count AS PostsOfType,
    COALESCE(vs.TotalVotes, 0) AS VoteCount
FROM 
    UserPostStats ups
LEFT JOIN 
    PostTypeCounts ptc ON ptc.PostTypeId IN (1, 2, 3, 4, 5, 6, 7, 8)
LEFT JOIN 
    VotesSummary vs ON ups.UserId = vs.PostId
ORDER BY 
    ups.TotalPosts DESC;