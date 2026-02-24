WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, '> <'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),

RecentComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(c.CreationDate) AS LastCommentDate
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        c.PostId
),

PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        us.DisplayName AS OwnerName,
        us.Reputation AS OwnerReputation,
        rc.CommentCount,
        rc.LastCommentDate
    FROM 
        RankedPosts rp
    JOIN 
        Users us ON rp.OwnerUserId = us.Id
    LEFT JOIN 
        RecentComments rc ON rp.PostId = rc.PostId
    WHERE 
        rp.Rank <= 10 
)

SELECT 
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.TagCount,
    pd.OwnerName,
    pd.OwnerReputation,
    pd.CommentCount,
    pd.LastCommentDate
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC;