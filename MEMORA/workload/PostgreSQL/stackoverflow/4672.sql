
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(rp.CommentCount) AS TotalComments,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes
    FROM 
        Users u
    JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(rp.UpVoteCount) > 5 OR SUM(rp.CommentCount) > 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    (tu.TotalUpVotes - tu.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN tu.TotalComments > 20 THEN 'Active Contributor'
        WHEN tu.TotalUpVotes > 10 THEN 'Popular User'
        ELSE 'New User'
    END AS UserStatus
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
WHERE 
    b.Class = 1 
    OR b.Class = 2
ORDER BY 
    NetVotes DESC
FETCH FIRST 10 ROWS ONLY;
