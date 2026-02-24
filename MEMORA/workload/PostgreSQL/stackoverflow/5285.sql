
WITH UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        RANK() OVER (ORDER BY SUM(u.UpVotes) - SUM(u.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostAggregates AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(p.Score) AS AverageScore,
        MAX(p.CreationDate) AS LatestActivity
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.TotalUpVotes,
    ur.TotalDownVotes,
    ur.TotalPosts,
    pa.PostId,
    pa.Title,
    pa.TotalComments,
    pa.TotalUpVotes AS PostUpVotes,
    pa.TotalDownVotes AS PostDownVotes,
    pa.AverageScore,
    pa.LatestActivity
FROM 
    UserRankings ur
JOIN 
    PostAggregates pa ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pa.PostId ORDER BY CreationDate DESC LIMIT 1)
WHERE 
    ur.UserRank <= 10
ORDER BY 
    ur.UserRank, pa.TotalComments DESC;
