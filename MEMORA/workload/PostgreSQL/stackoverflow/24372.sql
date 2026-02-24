
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= timestamp '2024-10-01 12:34:56' - INTERVAL '6 months'
    GROUP BY 
        v.PostId
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        p.PostId,
        p.Title,
        u.DisplayName,
        us.TotalPosts,
        us.TotalScore,
        COALESCE(rc.CommentCount, 0) AS TotalComments,
        COALESCE(rv.VoteCount, 0) AS TotalVotes,
        COALESCE(rv.UpVotes, 0) AS UpVotesCount,
        COALESCE(rv.DownVotes, 0) AS DownVotesCount,
        CASE 
            WHEN p.PostRank = 1 THEN 'Most Recent Post' 
            ELSE 'Previous Posts' 
        END AS PostStatus
    FROM 
        RankedPosts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserStatistics us ON u.Id = us.UserId
    LEFT JOIN 
        RecentVotes rv ON p.PostId = rv.PostId
    LEFT JOIN 
        PostComments rc ON p.PostId = rc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.DisplayName,
    fr.TotalPosts,
    fr.TotalScore,
    fr.TotalComments,
    fr.TotalVotes,
    fr.UpVotesCount,
    fr.DownVotesCount,
    fr.PostStatus
FROM 
    FinalResults fr
WHERE 
    fr.TotalComments > 5
ORDER BY 
    fr.TotalScore DESC, fr.TotalVotes DESC;
