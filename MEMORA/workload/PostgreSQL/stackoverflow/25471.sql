
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS RN
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '> <')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    u.DisplayName,
    u.Reputation,
    uvs.UpVotes,
    uvs.DownVotes,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS TopPostViewCount,
    tp.AnswerCount AS TopPostAnswerCount,
    tp.CommentCount AS TopPostCommentCount,
    tp.CreationDate AS TopPostCreationDate,
    STRING_AGG(pt.Tag, ', ') AS AssociatedTags
FROM 
    UserVoteSummary uvs
JOIN 
    Users u ON u.Id = uvs.UserId
LEFT JOIN 
    TopPosts tp ON tp.RN = 1 
LEFT JOIN 
    UserBadgeCounts ubc ON ubc.UserId = u.Id
LEFT JOIN 
    PostTags pt ON pt.PostId = tp.PostId
WHERE 
    uvs.PostCount > 5
GROUP BY 
    u.DisplayName, u.Reputation, uvs.UpVotes, uvs.DownVotes,
    ubc.GoldBadges, ubc.SilverBadges, ubc.BronzeBadges,
    tp.Title, tp.ViewCount, tp.AnswerCount, tp.CommentCount, tp.CreationDate
ORDER BY 
    u.Reputation DESC;
