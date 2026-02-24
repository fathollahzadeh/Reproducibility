WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2)  
),
PostStatistics AS (
    SELECT
        p.PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerDisplayName,
        p.PostRank,
        ph.UserId AS LastEditorId,
        ph.UserDisplayName AS LastEditorDisplayName,
        ph.CreationDate AS LastEditDate
    FROM 
        RankedPosts p
    LEFT JOIN 
        PostHistory ph ON p.PostId = ph.PostId AND ph.CreationDate IS NOT NULL
    WHERE 
        p.PostRank <= 10  
),
VoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerDisplayName,
    ps.LastEditorId,
    ps.LastEditorDisplayName,
    ps.LastEditDate,
    vc.UpVotes,
    vc.DownVotes,
    vc.TotalVotes
FROM 
    PostStatistics ps 
LEFT JOIN 
    VoteCounts vc ON ps.PostId = vc.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;