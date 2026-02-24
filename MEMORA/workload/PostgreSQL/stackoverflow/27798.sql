
WITH RankedPosts AS (
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopRankedPosts AS (
    
    SELECT 
        PostId,
        Title,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
UserInteractions AS (
    
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END) AS UpVoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount 
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    
    SELECT 
        trp.PostId,
        trp.Title,
        trp.ViewCount,
        trp.Score,
        ui.UserId,
        ui.DisplayName,
        ui.CommentCount,
        ui.VoteCount,
        ui.UpVoteCount,
        ui.DownVoteCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        UserInteractions ui ON ui.UserId IN (
            SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = trp.PostId
        )
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.Score,
    pd.DisplayName AS TopCommenter,
    pd.CommentCount,
    pd.VoteCount,
    pd.UpVoteCount,
    pd.DownVoteCount
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC, pd.Score DESC;
