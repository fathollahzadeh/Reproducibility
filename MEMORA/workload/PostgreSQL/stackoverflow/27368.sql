
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(REGEXP_SUBSTR(p.Body, '<h1>(.*?)</h1>'), 'No Description Available') AS PostDescription,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, u.DisplayName, p.Title, p.Body, p.LastActivityDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        rp.PostDescription
    FROM RankedPosts rp
    WHERE rp.RowNum = 1 
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpVoteCount - fp.DownVoteCount AS NetVotes,
    fp.PostDescription
FROM FilteredPosts fp
ORDER BY NetVotes DESC, fp.CommentCount DESC
FETCH FIRST 10 ROWS ONLY;
