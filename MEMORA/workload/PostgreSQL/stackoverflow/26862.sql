
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts p WHERE p.OwnerUserId = u.Id AND p.PostTypeId = 1) AS QuestionCount,
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.TagCount,
    rp.AcceptedAnswerId,
    rp.PostRank
FROM 
    TopUsers tu
JOIN 
    RankedPosts rp ON tu.UserId = rp.OwnerUserId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    tu.Reputation DESC, rp.Score DESC;
