
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.PostCount,
        ua.Upvotes,
        ua.Downvotes,
        RANK() OVER (ORDER BY ua.PostCount DESC) AS PostRank
    FROM 
        UserActivity ua
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.ScoreRank,
    rp.ViewRank,
    tu.UserId,
    tu.PostCount,
    tu.Upvotes,
    tu.Downvotes
FROM 
    RankedPosts rp
JOIN 
    TopUsers tu ON rp.PostId = (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = tu.UserId ORDER BY p.CreationDate DESC LIMIT 1)
WHERE 
    rp.ScoreRank <= 10 OR rp.ViewRank <= 10
ORDER BY 
    rp.ScoreRank, rp.ViewRank, tu.PostCount DESC;
