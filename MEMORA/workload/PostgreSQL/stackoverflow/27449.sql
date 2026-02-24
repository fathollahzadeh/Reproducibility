
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CreationDate,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS RankScore,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, p.AnswerCount, p.CreationDate, p.Tags
),
UserPostInteraction AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(ph.RankScore, 0)) AS TotalPostRank,
        SUM(u.UpVotes + u.DownVotes) AS TotalVotes,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        RankedPosts ph ON p.Id = ph.PostId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName
),
FinalReport AS (
    SELECT 
        uli.UserId,
        uli.DisplayName,
        uli.PostsCreated,
        uli.TotalPostRank,
        uli.TotalVotes,
        uli.AvgViewCount,
        ROW_NUMBER() OVER (ORDER BY uli.TotalPostRank DESC) AS UserRank
    FROM 
        UserPostInteraction uli
    WHERE 
        uli.PostsCreated > 10  
)
SELECT 
    fr.UserId,
    fr.DisplayName,
    fr.PostsCreated,
    fr.TotalPostRank,
    fr.TotalVotes,
    fr.AvgViewCount,
    fr.UserRank
FROM 
    FinalReport fr
WHERE 
    fr.UserRank <= 10  
ORDER BY 
    fr.UserRank;
