WITH RecursivePostContributions AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= '2022-01-01' 
        AND p.Score > 0
    GROUP BY 
        p.Id, p.OwnerUserId
), 
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(r.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(r.UpVotes), 0) AS TotalUpVotes,
        COALESCE(SUM(r.DownVotes), 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(r.UpVotes), 0) DESC) AS RankByUpVotes
    FROM 
        Users u
    LEFT JOIN 
        RecursivePostContributions r ON u.Id = r.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.TotalComments,
    up.TotalUpVotes,
    up.TotalDownVotes,
    (up.TotalUpVotes - up.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN up.RankByUpVotes <= 10 THEN 'Top Contributor'
        WHEN up.TotalUpVotes > 100 THEN 'Active User'
        ELSE 'Regular User'
    END AS UserTier
FROM 
    UserPerformance up
WHERE 
    up.TotalUpVotes > 0
ORDER BY 
    up.TotalUpVotes DESC;
