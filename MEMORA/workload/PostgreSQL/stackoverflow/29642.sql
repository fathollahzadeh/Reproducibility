
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        COALESCE(ARRAY_LENGTH(string_to_array(rp.Tags, '>'), 1), 0) AS TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN = 1
      AND rp.CommentCount > 0
      AND rp.UpVoteCount > rp.DownVoteCount
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.CommentCount,
    fp.AnswerCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.TagCount,
    (SELECT STRING_AGG(Name, ', ') 
     FROM PostHistory ph 
     JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id 
     WHERE ph.PostId = fp.PostId 
     AND pht.Name LIKE 'Edit%') AS EditHistory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVoteCount DESC, fp.CommentCount DESC;
