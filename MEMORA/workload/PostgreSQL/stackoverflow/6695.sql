
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(up.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(down.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount
         FROM Votes
         WHERE VoteTypeId = 2
         GROUP BY PostId) up ON p.Id = up.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS DownVoteCount
         FROM Votes
         WHERE VoteTypeId = 3
         GROUP BY PostId) down ON p.Id = down.PostId
),
PostedBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    JOIN 
        Users u ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        pb.BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        PostedBadges pb ON u.Id = pb.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.BadgeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.CreationDate DESC;
