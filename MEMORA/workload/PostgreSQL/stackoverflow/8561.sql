
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(*) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        v.UserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.VoteCount,
        us.UpVotes,
        us.DownVotes,
        RANK() OVER (ORDER BY us.VoteCount DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        UserVoteStats us ON u.Id = us.UserId
    WHERE 
        us.VoteCount > 0
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    tu.DisplayName AS TopUser,
    tu.UserRank
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON tu.UserRank <= 10
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
