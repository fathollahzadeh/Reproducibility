
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),
UserInteraction AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS EditDate,
        ph.UserDisplayName,
        ph.Comment AS EditComment,
        ph.Text AS NewBody
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
AggregatedPostHistory AS (
    SELECT 
        p.PostId,
        MAX(ph.EditDate) AS LastEditDate,
        STRING_AGG(CONCAT(ph.UserDisplayName, ' - ', ph.EditComment), '; ') AS EditsDetails
    FROM 
        TopPosts p
    LEFT JOIN 
        PostHistoryDetails ph ON ph.PostId = p.PostId
    GROUP BY 
        p.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CommentCount,
    tp.Tags,
    up.DisplayName AS TopUser,
    up.TotalUpVotes,
    up.TotalDownVotes,
    aph.LastEditDate,
    aph.EditsDetails
FROM 
    TopPosts tp
LEFT JOIN 
    UserInteraction up ON up.UserId = tp.PostId
LEFT JOIN 
    AggregatedPostHistory aph ON aph.PostId = tp.PostId
WHERE 
    (COALESCE(up.TotalUpVotes, 0) - COALESCE(up.TotalDownVotes, 0)) > 10 
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;
