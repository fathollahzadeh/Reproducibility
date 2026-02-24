
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2) ORDER BY p.ViewCount DESC) AS TagRank,
        COUNT(c.Id) AS CommentCount,
        p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        au.DisplayName AS OwnerDisplayName,
        au.TotalPosts,
        au.UpVotes,
        au.DownVotes,
        rp.CommentCount
    FROM RankedPosts rp
    JOIN AggregatedUserStats au ON rp.OwnerUserId = au.UserId
    WHERE rp.TagRank <= 5
    ORDER BY rp.TagRank, rp.ViewCount DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerDisplayName,
    tp.TotalPosts,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    CASE 
        WHEN tp.Score > 100 THEN 'Highly Voted'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Moderately Voted'
        ELSE 'Low Votes'
    END AS VoteCategory
FROM TopPosts tp
ORDER BY tp.ViewCount DESC
LIMIT 10;
