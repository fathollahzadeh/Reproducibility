
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score > 0
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
Closures AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
HighPerformers AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        u.DisplayName AS OwnerName,
        us.TotalUpVotes,
        us.TotalDownVotes,
        COALESCE(cl.CloseCount, 0) AS TotalClosures,
        COALESCE(pc.CommentCount, 0) AS TotalComments
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserStats us ON u.Id = us.UserId
    LEFT JOIN 
        Closures cl ON rp.Id = cl.PostId
    LEFT JOIN 
        PostComments pc ON rp.Id = pc.PostId
    WHERE 
        rp.RankByScore <= 5
)
SELECT 
    h.PostId,
    h.Title,
    h.CreationDate,
    h.Score,
    h.ViewCount,
    h.OwnerName,
    h.TotalUpVotes,
    h.TotalDownVotes,
    h.TotalClosures,
    h.TotalComments,
    (CASE 
        WHEN h.TotalUpVotes > h.TotalDownVotes THEN 'Positive'
        WHEN h.TotalDownVotes > h.TotalUpVotes THEN 'Negative'
        ELSE 'Neutral'
    END) AS VoteSentiment
FROM 
    HighPerformers h
ORDER BY 
    h.Score DESC, h.ViewCount DESC;
