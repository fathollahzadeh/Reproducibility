
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC, SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    CONCAT('This post has ', fp.CommentCount, ' comments and ', fp.UpVotes, ' upvotes.') AS Summary,
    STRING_AGG(DISTINCT t.TagName, ', ') AS AssociatedTags
FROM 
    FilteredPosts fp
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(SUBSTRING(fp.Tags FROM 2 FOR LENGTH(fp.Tags) - 2), '><')) AS TagName
    ) AS t ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.Tags, fp.OwnerDisplayName, fp.CreationDate, fp.CommentCount, fp.UpVotes, fp.DownVotes
ORDER BY 
    fp.UpVotes DESC, fp.CommentCount DESC;
