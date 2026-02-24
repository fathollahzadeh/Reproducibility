
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        RANK() OVER (ORDER BY SUM(p.UpVotes - p.DownVotes) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        RankedPosts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tu.UserRank,
    tu.DisplayName,
    rp.Title,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    CASE 
        WHEN rp.UpVotes - rp.DownVotes > 0 THEN 'Positive'
        WHEN rp.UpVotes - rp.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopUsers tu
INNER JOIN 
    RankedPosts rp ON tu.Id = rp.OwnerUserId
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.UserRank, rp.UpVotes DESC;
