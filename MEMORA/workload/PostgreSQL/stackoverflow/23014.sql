
WITH RecursivePostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(v.TotalVotes, 0) AS TotalVotes,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(pv.ViewCount, 0) AS TotalViews,
        CASE 
            WHEN p.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Old Post'
            ELSE 'Recent Post'
        END AS PostAge,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            Id AS PostId,
            ViewCount
        FROM 
            Posts
        WHERE 
            ViewCount IS NOT NULL
    ) pv ON p.Id = pv.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(pa.TotalVotes) AS UserTotalVotes,
        SUM(pa.TotalComments) AS UserTotalComments,
        COUNT(DISTINCT pa.PostId) AS UserPostCount
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostAnalytics pa ON u.Id = pa.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UserTotalVotes,
        UserTotalComments,
        UserPostCount,
        RANK() OVER (ORDER BY UserTotalVotes DESC, UserTotalComments DESC) AS EngagementRank
    FROM 
        UserEngagement
    WHERE 
        UserPostCount > 5
)
SELECT 
    u.Id,
    u.DisplayName,
    tp.UserTotalVotes,
    tp.UserTotalComments,
    tp.UserPostCount,
    tp.EngagementRank,
    CASE 
        WHEN tp.UserTotalVotes > 100 THEN 'Highly Engaged'
        WHEN tp.UserTotalVotes BETWEEN 50 AND 100 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementCategory,
    ARRAY_AGG(DISTINCT t.TagName) AS UserTags
FROM 
    TopUsers tp
JOIN 
    Users u ON tp.UserId = u.Id
LEFT JOIN 
    (
        SELECT 
            p.OwnerUserId,
            unnest(string_to_array(p.Tags, '>')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Tags IS NOT NULL
    ) t ON u.Id = t.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, tp.UserTotalVotes, tp.UserTotalComments, tp.UserPostCount, tp.EngagementRank
ORDER BY 
    tp.EngagementRank;
