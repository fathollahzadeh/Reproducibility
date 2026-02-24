
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 3 
)
SELECT 
    fp.OwnerDisplayName,
    fp.Title,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    STRING_AGG(t.TagName, ', ') AS TagsAggregated
FROM 
    FilteredPosts fp
LEFT JOIN 
    Badges b ON fp.OwnerUserId = b.UserId
LEFT JOIN 
    LATERAL (
        SELECT 
            unnest(string_to_array(SUBSTR(fp.Tags, 2, LENGTH(fp.Tags)-2), '><')) AS TagName
    ) t ON TRUE
GROUP BY 
    fp.OwnerDisplayName, fp.Title, fp.CommentCount, fp.UpVoteCount, fp.DownVoteCount
ORDER BY 
    UpVoteCount DESC, CommentCount DESC;
