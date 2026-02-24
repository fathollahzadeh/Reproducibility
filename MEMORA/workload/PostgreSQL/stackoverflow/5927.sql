
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(r.UpVotes) AS TotalUpVotes,
        SUM(r.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts r ON u.Id = r.OwnerUserId
    WHERE 
        r.Rank <= 5
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.DisplayName,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    COUNT(DISTINCT rp.PostId) AS PostCount,
    AVG(rp.CommentCount) AS AvgCommentsPerPost
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
GROUP BY 
    tu.DisplayName, tu.TotalUpVotes, tu.TotalDownVotes
ORDER BY 
    tu.TotalUpVotes DESC, tu.TotalDownVotes ASC
LIMIT 10;
