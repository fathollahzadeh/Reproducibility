
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.Score > 0
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id
),
PostCommentAggregates AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(pr.Name, ', ') AS ClosureReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes pr ON CAST(ph.Comment AS INT) = pr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ps.UpVotes,
    ps.DownVotes,
    pca.CommentCount,
    pca.Comments,
    cp.LastClosedDate,
    cp.ClosureReasons,
    rp.OwnerDisplayName
FROM 
    RankedPosts rp
JOIN 
    PostVoteSummary ps ON rp.PostId = ps.PostId
LEFT JOIN 
    PostCommentAggregates pca ON rp.PostId = pca.PostId
LEFT JOIN 
    ClosedPostDetails cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank = 1  
ORDER BY 
    rp.CreationDate DESC
LIMIT 100
OFFSET 0;
