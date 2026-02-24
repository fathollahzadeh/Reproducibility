
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (
            PARTITION BY p.PostTypeId 
            ORDER BY p.Score DESC, p.ViewCount DESC
        ) AS RankByScoreViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount  
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
MaxEngagement AS (
    SELECT 
        UserId,
        PostCount,
        UpvoteCount,
        DownvoteCount,
        RANK() OVER (ORDER BY PostCount DESC, UpvoteCount DESC) AS EngagementRank
    FROM 
        UserEngagement
),
BadgedUsers AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1  
    GROUP BY 
        b.UserId
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        pe.PostCount,
        pe.UpvoteCount,
        pe.DownvoteCount,
        bu.BadgeCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        CASE 
            WHEN COALESCE(pc.CommentCount, 0) > 0 THEN 'Has Comments'
            ELSE 'No Comments'
        END AS CommentStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        MaxEngagement pe ON pe.UserId = rp.PostId  
    LEFT JOIN 
        BadgedUsers bu ON bu.UserId = rp.PostId   
    LEFT JOIN 
        PostComments pc ON pc.PostId = rp.PostId
    WHERE 
        rp.RankByScoreViews <= 5
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.PostCount,
    fr.UpvoteCount,
    fr.DownvoteCount,
    fr.BadgeCount,
    fr.CommentCount,
    fr.CommentStatus
FROM 
    FinalReport fr
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC;
