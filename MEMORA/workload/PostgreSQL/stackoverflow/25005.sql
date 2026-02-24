
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        Tags,
        CreationDate,
        Author,
        AnswerCount,
        Upvotes,
        Downvotes
    FROM 
        RankedPosts
    WHERE 
        TagRank <= 5
),
PostDetails AS (
    SELECT 
        fp.*, 
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        PostHistory ph ON fp.PostId = ph.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.Body, fp.Tags, fp.CreationDate, fp.Author, fp.AnswerCount, fp.Upvotes, fp.Downvotes
)
SELECT 
    pd.PostId, 
    pd.Title, 
    pd.Body,
    pd.Tags,
    pd.CreationDate, 
    pd.Author, 
    pd.AnswerCount, 
    pd.Upvotes, 
    pd.Downvotes, 
    pd.CommentCount,
    pd.CloseCount,
    pd.ReopenCount,
    CASE 
        WHEN pd.CloseCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM 
    PostDetails pd
ORDER BY 
    pd.Upvotes DESC, pd.AnswerCount DESC
FETCH FIRST 10 ROWS ONLY;
