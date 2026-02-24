
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId
),

HighScoredPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        CommentCount,
        RankByScore
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
),

UserActivity AS (
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

PostsWithBadges AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        b.Name AS BadgeName,
        b.Class,
        b.Date AS BadgeDate
    FROM 
        Posts p
    JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        b.Class = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
),

FinalResult AS (
    SELECT 
        hp.PostId,
        hp.Title,
        hp.Score,
        ua.DisplayName,
        ua.TotalUpVotes,
        ua.TotalDownVotes,
        pb.BadgeName,
        pb.BadgeDate
    FROM 
        HighScoredPosts hp
    LEFT JOIN 
        UserActivity ua ON hp.CommentCount > 5 AND ua.UserId = hp.PostId
    LEFT JOIN 
        PostsWithBadges pb ON hp.PostId = pb.PostId
)

SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.DisplayName,
    COALESCE(fr.TotalUpVotes, 0) AS TotalUpVotes,
    COALESCE(fr.TotalDownVotes, 0) AS TotalDownVotes,
    fr.BadgeName,
    fr.BadgeDate
FROM 
    FinalResult fr
ORDER BY 
    fr.Score DESC, fr.PostId ASC;
