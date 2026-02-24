
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS AuthorName,
        p.CreationDate,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount,
        (SELECT STRING_AGG(b.Name, ', ') FROM Badges b WHERE b.UserId = p.OwnerUserId) AS UserBadges
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year' 
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><'))
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 5 
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.AuthorName,
        pd.CommentCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        pd.UserBadges,
        tt.Tag,
        ROW_NUMBER() OVER (PARTITION BY tt.Tag ORDER BY pd.UpVoteCount DESC) AS PostRank
    FROM 
        PostDetails pd
    JOIN 
        TagStatistics ts ON EXISTS (
            SELECT 1 
            FROM unnest(string_to_array(substring(pd.Tags, 2, LENGTH(pd.Tags) - 2), '><')) AS tbl(Tag) 
            WHERE tbl.Tag = ts.Tag
        )
    JOIN 
        TopTags tt ON tt.Tag = ts.Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.AuthorName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.UserBadges,
    rp.Tag,
    rp.PostRank
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    rp.Tag, rp.UpVoteCount DESC;
