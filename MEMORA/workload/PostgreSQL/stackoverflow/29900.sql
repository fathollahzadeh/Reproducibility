
WITH CombinedPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (SELECT COUNT(CASE WHEN b.Class = 1 THEN 1 ELSE NULL END) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS GoldBadges,
        (SELECT COUNT(CASE WHEN b.Class = 2 THEN 1 ELSE NULL END) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS SilverBadges,
        (SELECT COUNT(CASE WHEN b.Class = 3 THEN 1 ELSE NULL END) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BronzeBadges
    FROM 
        Posts p
        JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
),

PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(p.Tags, ',')) AS TagName
    FROM 
        Posts p
),

TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        PostTagCounts pt
        JOIN Users u ON pt.PostId = u.Id
    GROUP BY 
        TagName
)

SELECT 
    cp.PostId,
    cp.Title,
    cp.Body,
    cp.CreationDate,
    cp.OwnerDisplayName,
    cp.Reputation,
    cp.CommentCount,
    cp.UpVotes,
    cp.DownVotes,
    cp.GoldBadges,
    cp.SilverBadges,
    cp.BronzeBadges,
    pt.TagName,
    ts.PostCount,
    ts.AvgReputation
FROM 
    CombinedPostData cp
JOIN 
    PostTagCounts pt ON cp.PostId = pt.PostId
JOIN 
    TagStatistics ts ON pt.TagName = ts.TagName
WHERE 
    cp.Reputation > 1000
ORDER BY 
    cp.CreationDate DESC, 
    ts.PostCount DESC
LIMIT 50;
