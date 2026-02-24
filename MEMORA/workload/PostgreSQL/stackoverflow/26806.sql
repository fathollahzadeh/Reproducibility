WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenedEvents,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
), FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Author,
        CommentCount,
        UpVotes,
        DownVotes,
        CloseReopenedEvents
    FROM 
        RankedPosts
    WHERE 
        RowNum = 1 
)
SELECT 
    f.PostId,
    f.Title,
    f.Author,
    f.CreationDate,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.CloseReopenedEvents,
    CASE 
        WHEN f.UpVotes > f.DownVotes THEN 'Positive Outweighs'
        WHEN f.UpVotes < f.DownVotes THEN 'Negative Outweighs'
        ELSE 'Neutral'
    END AS OverallVoteBias
FROM 
    FilteredPosts f
WHERE 
    f.CommentCount > 5 
ORDER BY 
    f.UpVotes DESC, 
    f.CommentCount DESC;