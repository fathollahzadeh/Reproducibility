
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(COALESCE(UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(DownVotes, 0)) AS TotalDownVotes,
        AVG(EXTRACT(EPOCH FROM (p.CreationDate - c.CreationDate))) AS AvgTimeToComment
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        pt.Name AS PostType,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(MIN(ph.CreationDate), '9999-12-31') AS FirstHistoryEntry
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY 
        p.Id, p.Title, pt.Name
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    pa.PostId,
    pa.Title,
    pa.PostType,
    pa.CommentCount,
    ua.TotalUpVotes - ua.TotalDownVotes AS NetVotes,
    CASE 
        WHEN pa.FirstHistoryEntry > '2023-01-01' THEN 'Recently Updated'
        ELSE 'Stable'
    END AS PostStatus,
    ROW_NUMBER() OVER (PARTITION BY ua.UserId ORDER BY pa.CommentCount DESC) AS Rank
FROM 
    UserActivity ua
JOIN 
    PostAnalytics pa ON ua.UserId = (SELECT p.OwnerUserId FROM Posts p WHERE p.Id = pa.PostId LIMIT 1)
WHERE 
    ua.TotalPosts > 0 
    AND pa.CommentCount > 5
ORDER BY 
    NetVotes DESC, ua.DisplayName ASC;
