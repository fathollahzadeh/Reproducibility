
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.Tags,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
TopTagPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.Tags,
        ur.DisplayName,
        ur.Reputation,
        ur.PostCount,
        ur.UpVoteCount
    FROM
        RankedPosts rp
    JOIN
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE
        rp.TagRank <= 3  
)
SELECT
    tt.Tags,
    COUNT(tt.PostId) AS PostCount,
    AVG(tt.UpVoteCount) AS AvgUpVotes,
    AVG(tt.Reputation) AS AvgReputation,
    MIN(tt.CreationDate) AS EarliestPostDate,
    MAX(tt.CreationDate) AS LatestPostDate
FROM
    TopTagPosts tt
GROUP BY
    tt.Tags
ORDER BY
    PostCount DESC, AvgReputation DESC;
