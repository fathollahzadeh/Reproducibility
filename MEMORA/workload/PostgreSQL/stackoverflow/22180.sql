
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.ParentId,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM p.CreationDate) ORDER BY p.Score DESC, p.ViewCount DESC) AS RankInYear,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '5 years'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.ParentId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        ParentId,
        RankInYear,
        CommentCount,
        UpVotesCount,
        DownVotesCount
    FROM 
        RankedPosts
    WHERE 
        RankInYear <= 10 
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(b.Class), 0) AS TotalBadges,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < CURRENT_DATE 
    GROUP BY 
        u.Id, u.DisplayName
),
FinalOutput AS (
    SELECT 
        tp.Title,
        tp.Score,
        tp.ViewCount,
        u.DisplayName AS Owner,
        tp.CommentCount,
        tp.UpVotesCount,
        tp.DownVotesCount
    FROM 
        TopPosts tp
    JOIN 
        UserEngagement u ON tp.ParentId = u.UserId OR tp.ParentId IS NULL  
    WHERE 
        tp.Score > 10 
)

SELECT 
    FO.Title,
    FO.Owner,
    FO.Score,
    FO.ViewCount,
    FO.CommentCount,
    (FO.UpVotesCount - FO.DownVotesCount) AS NetVotes,
    CASE 
        WHEN FO.Score > 100 THEN 'Highly Rated'
        WHEN FO.Score BETWEEN 50 AND 100 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory
FROM 
    FinalOutput FO
ORDER BY 
    FO.Score DESC, 
    FO.ViewCount DESC;
